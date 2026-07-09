from rest_framework import serializers
from .models import Student, Class, get_next_gr_number


class ClassSerializer(serializers.ModelSerializer):
    class Meta:
        model = Class
        fields = '__all__'

class StudentSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_phone = serializers.CharField(source='user.phone', read_only=True)
    student_class_name = serializers.CharField(
        source='student_class.name', read_only=True)
    student_class_display = serializers.SerializerMethodField()
    class_name = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = Student
        fields = '__all__'
        extra_kwargs = {'student_class': {'required': False}}

    def create(self, validated_data):
        class_name = validated_data.pop('class_name', None)
        if class_name:
            class_obj, _ = Class.objects.get_or_create(name=class_name)
            validated_data['student_class'] = class_obj

        return super().create(validated_data)

    def get_student_class_display(self, obj):
        if not obj.student_class:
            return ""
        return str(obj.student_class)
